const path = require('path');

module.exports = function(env) {
	const production = process.env.NODE_ENV === 'production';
	return {
		devtool: production ? 'source-maps' : 'eval',
		entry: './assets/js/app.js',
		output: (production
		? {
			path: path.resolve(__dirname, './priv/static/js'),
			filename: 'app.js',
			publicPath: '/',
		}
		: {
			path: path.resolve(__dirname, 'public'),
			filename: 'app.js',
			publicPath: 'http://localhost:8080/',
		}),
		module: {
			rules: [
				{
					test: /\.js$/,
					exclude: /node_modules/,
					use: {
						loader: 'babel-loader',
					},
				},
			],
		},
		resolve: {
			modules: ['node_modules', path.resolve(__dirname, './assets/js')],
			extensions: ['.js'],
		},
		devServer: {
			headers: {
				'Access-Control-Allow-Origin': '*',
			},
		},
	};
};
